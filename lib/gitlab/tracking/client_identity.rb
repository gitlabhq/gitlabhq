# frozen_string_literal: true

module Gitlab
  module Tracking
    # Which kind of client made the current request, for analytics attribution.
    #
    # Resolved once per request from the X-Gitlab-Client-Type and
    # X-Gitlab-Client-Name headers, then the User-Agent, and stored on
    # ApplicationContext so every Sidekiq job the request enqueues inherits it.
    # Only allowlisted values are kept: the headers are client-controlled.
    class ClientIdentity
      Identity = Struct.new(:type, :name)

      TYPES = %w[browser ide cli mobile integration system api].freeze

      # Values clients already send in X-Gitlab-Client-Type that predate the taxonomy.
      TYPE_ALIASES = { 'web' => 'browser', 'web_browser' => 'browser', 'duo_cli' => 'cli' }.freeze

      # Browser family ids from the `browser` gem. They come from the User-Agent, or from
      # the name header when Workhorse forwards the family Rails resolved for the session.
      BROWSER_NAMES = %w[chrome firefox safari edge opera electron].freeze

      # Allowlisted name slugs and the type each belongs to.
      NAMES = {
        'gitlab-mobile-ios' => 'mobile',
        'gitlab-mobile-android' => 'mobile',
        'vscode' => 'ide',
        'jetbrains' => 'ide',
        'jetbrains-bundled' => 'ide',
        'visual-studio' => 'ide',
        'neovim' => 'ide',
        'zed' => 'ide',
        'kiro' => 'ide',
        'duo-cli' => 'cli',
        'glab' => 'cli',
        'slack' => 'integration',
        'mcp' => 'integration',
        'gitlab-rails' => 'system'
      }.merge(BROWSER_NAMES.index_with('browser')).freeze

      # Product names clients already send in X-Gitlab-Client-Name, lowercased.
      NAME_ALIASES = {
        'visual studio code' => 'vscode',
        'gitlab' => 'vscode',
        'gitlab workflow' => 'vscode',
        'gitlab-jetbrains-plugin' => 'jetbrains',
        # The JetBrains plugin's display name, sent as the language server's extension name.
        # The Eclipse plugin sends the same name and counts as JetBrains until it gets its own slug (#630922).
        'gitlab duo' => 'jetbrains',
        'intellij idea' => 'jetbrains',
        'pycharm' => 'jetbrains',
        'rubymine' => 'jetbrains',
        'phpstorm' => 'jetbrains',
        'goland' => 'jetbrains',
        'webstorm' => 'jetbrains',
        'jetbrains rider' => 'jetbrains',
        'android studio' => 'jetbrains',
        'gl-visual-studio-extension' => 'visual-studio',
        'microsoft visual studio' => 'visual-studio',
        'gitlab.vim' => 'neovim',
        'neovim lsp client' => 'neovim',
        'zed duo extension' => 'zed',
        'duo cli' => 'duo-cli',
        'gitlab-duo-cli' => 'duo-cli'
      }.freeze

      USER_AGENT_NAMES = {
        UsageDataCounters::VSCodeExtensionActivityUniqueCounter::VS_CODE_USER_AGENT_REGEX => 'vscode',
        UsageDataCounters::JetBrainsPluginActivityUniqueCounter::JETBRAINS_USER_AGENT_REGEX => 'jetbrains',
        UsageDataCounters::JetBrainsBundledPluginActivityUniqueCounter::JETBRAINS_BUNDLED_USER_AGENT_REGEX =>
          'jetbrains-bundled',
        UsageDataCounters::VisualStudioExtensionActivityUniqueCounter::VISUAL_STUDIO_EXTENSION_USER_AGENT_REGEX =>
          'visual-studio',
        UsageDataCounters::NeovimPluginActivityUniqueCounter::NEOVIM_PLUGIN_USER_AGENT_REGEX => 'neovim',
        UsageDataCounters::GitLabCliActivityUniqueCounter::GITLAB_CLI_USER_AGENT_REGEX => 'glab'
      }.freeze

      # Requests GitLab components make to GitLab: runner polling, git over HTTP,
      # gitlab-shell, and Workhorse running an agent's HTTP actions for a
      # websocket client (which forwards the client headers when it has them).
      SYSTEM_USER_AGENT_REGEX =
        %r{\A(gitlab-runner|git/|GitLab-Shell|gitlab-workhorse|Agent-Flow-via-GitLab-Workhorse)}i
      BROWSER_USER_AGENT_REGEX = %r{\AMozilla/}

      SYSTEM = Identity.new('system', 'gitlab-rails').freeze
      API = Identity.new('api', nil).freeze

      class << self
        def from_request(request)
          user_agent = request.user_agent
          identity = from_headers(request.headers['X-Gitlab-Client-Type'], request.headers['X-Gitlab-Client-Name'])
          return from_user_agent(user_agent) unless identity
          return identity unless identity.type == 'browser' && identity.name.nil?

          # The web frontend only declares its type; the browser family comes from the User-Agent.
          Identity.new('browser', browser_name(user_agent))
        end

        def from_headers(type_header, name_header)
          type = normalize_type(type_header)
          name = normalize_name(name_header)
          # A declared type wins; a name of another type (Workhorse's fallback name, say) is dropped.
          name = nil if type && name && NAMES[name] != type

          return Identity.new(type, name) if type
          return Identity.new(NAMES.fetch(name), name) if name

          nil
        end

        def from_user_agent(user_agent)
          # Header values may carry invalid UTF-8; String#match? would raise.
          user_agent = user_agent.to_s.scrub
          return API if user_agent.blank?
          return SYSTEM if user_agent.match?(SYSTEM_USER_AGENT_REGEX)

          name = USER_AGENT_NAMES.find { |regex, _name| user_agent.match?(regex) }&.last
          return Identity.new(NAMES.fetch(name), name) if name
          return Identity.new('browser', browser_name(user_agent)) if user_agent.match?(BROWSER_USER_AGENT_REGEX)

          API
        end

        # The identity of the request this code runs for, also inside Sidekiq
        # jobs that request enqueued. Nil when there is no request lineage.
        def current
          type = Gitlab::ApplicationContext.current_context_attribute(:client_type)
          return unless type

          Identity.new(type, Gitlab::ApplicationContext.current_context_attribute(:client_name))
        end

        private

        def browser_name(user_agent)
          name = ::Browser.new(user_agent.to_s.scrub).id.to_s
          name if BROWSER_NAMES.include?(name)
        rescue ::Browser::Error
          # The gem refuses a User-Agent over 2 KB; the type still stands without a name.
          nil
        end

        def normalize_type(value)
          type = normalize(value)
          return unless type

          type = TYPE_ALIASES.fetch(type, type)
          type if TYPES.include?(type)
        end

        def normalize_name(value)
          name = normalize(value)
          return unless name

          name = NAME_ALIASES.fetch(name, name)
          name if NAMES.key?(name)
        end

        def normalize(value)
          normalized = value.to_s.scrub.strip.downcase
          normalized unless normalized.empty?
        end
      end
    end
  end
end
