# frozen_string_literal: true

require 'wikicloth'
require 'wikicloth/wiki_buffer/var'

# Adds patch for changes in this PR: https://github.com/nricciar/wikicloth/pull/112/files
#
# That fix has already been merged, but the maintainers are not releasing new versions, so we
# need to patch it here.
#
# If they ever do release a version, then we can remove this file.
#
# See: https://gitlab.com/gitlab-org/gitlab/-/issues/334056#note_745336618

# Guard to ensure we remember to delete this patch if they ever release a new version of wikicloth
raise 'New version of WikiCloth detected, please remove this patch' unless Gem::Version.new(WikiCloth::VERSION) == Gem::Version.new('0.8.1')

# rubocop:disable Style/ClassAndModuleChildren
# rubocop:disable Layout/SpaceAroundEqualsInParameterDefault
# rubocop:disable Style/HashSyntax
# rubocop:disable Layout/SpaceAfterComma
# rubocop:disable Style/RescueStandardError
# rubocop:disable Rails/Output
# rubocop:disable Style/MethodCallWithoutArgsParentheses
# rubocop:disable Layout/EmptyLinesAroundClassBody
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/PerceivedComplexity
# rubocop:disable Cop/LineBreakAroundConditionalBlock
# rubocop:disable Layout/EmptyLineAfterGuardClause
# rubocop:disable Performance/ReverseEach
# rubocop:disable Style/BlockDelimiters
# rubocop:disable Cop/LineBreakAroundConditionalBlock
# rubocop:disable Layout/MultilineBlockLayout
# rubocop:disable Layout/BlockEndNewline
module WikiCloth
  class WikiCloth
    def render(opt={})
      self.options = { :noedit => false, :locale => I18n.default_locale, :fast => true, :output => :html, :link_handler => self.link_handler,
                       :params => self.params, :sections => self.sections }.merge(self.options).merge(opt)
      self.options[:link_handler].params = options[:params]

      I18n.locale = self.options[:locale]

      data = self.sections.collect { |s| s.render(self.options) }.join

      # This is the first patched line from:
      # https://github.com/nricciar/wikicloth/pull/112/files#diff-eed3de11b953105f9181a6859d58f52af8912d28525fd2a289f8be184e66f531R69
      data.gsub!(/<!--.*?-->/m,"")

      data << "\n" if data.last(1) != "\n"
      data << "garbage"

      buffer = WikiBuffer.new("",options)

      begin
        if self.options[:fast]
          until data.empty?
            case data
            when /\A\w+/
              data = $'
              @current_row += $&.length
              buffer.add_word($&)
            when /\A[^\w]+(\w|)/m
              data = $'
              $&.each_char { |c| add_current_char(buffer,c) }
            end
          end
        else
          data.each_char { |c| add_current_char(buffer,c) }
        end
      rescue => err
        debug_tree = buffer.buffers.collect { |b| b.debug }.join("-->")
        puts I18n.t("unknown error on line", :line => @current_line, :row => @current_row, :tree => debug_tree)
        raise err
      end

      buffer.eof()
      buffer.send("to_#{self.options[:output]}")
    end

  end

  class WikiBuffer::Var < WikiBuffer
    def to_html
      return "" if will_not_be_rendered

      if self.is_function?
        if Extension.function_exists?(function_name)
          return Extension.functions[function_name][:klass].new(@options).instance_exec( params.collect { |p| p.strip }, &Extension.functions[function_name][:block] ).to_s
        end
        ret = default_functions(function_name,params.collect { |p| p.strip })
        ret ||= @options[:link_handler].function(function_name, params.collect { |p| p.strip })
        ret.to_s
      elsif self.is_param?
        ret = nil
        @options[:buffer].buffers.reverse.each do |b|
          ret = b.get_param(params[0],params[1]) if b.instance_of?(WikiBuffer::HTMLElement) && b.element_name == "template"
          break unless ret.nil?
        end
        ret.to_s
      else
        # put template at beginning of buffer
        template_stack = @options[:buffer].buffers.collect { |b| b.get_param("__name") if b.instance_of?(WikiBuffer::HTMLElement) &&
          b.element_name == "template" }.compact
        if template_stack.last == params[0]
          debug_tree = @options[:buffer].buffers.collect { |b| b.debug }.join("-->")
          "<span class=\"error\">#{I18n.t('template loop detected', :tree => debug_tree)}</span>"
        else
          key = params[0].to_s.strip
          key_options = params[1..].collect { |p| p.is_a?(Hash) ? { :name => p[:name].strip, :value => p[:value].strip } : p.strip }
          key_options ||= []
          key_digest = Digest::MD5.hexdigest(key_options.to_a.sort {|x,y| (x.is_a?(Hash) ? x[:name] : x) <=> (y.is_a?(Hash) ? y[:name] : y) }.inspect)

          return @options[:params][key] if @options[:params].has_key?(key)
          # if we have a valid cache fragment use it
          return @options[:cache][key][key_digest] unless @options[:cache].nil? || @options[:cache][key].nil? || @options[:cache][key][key_digest].nil?

          ret = @options[:link_handler].include_resource(key,key_options).to_s

          # This is the second patched line from:
          # https://github.com/nricciar/wikicloth/pull/112/files#diff-f262faf4fadb222cca87185be0fb65b3f49659abc840794cc83a736d41310fb1R83
          ret.gsub!(/<!--.*?-->/m,"") unless ret.frozen?

          count = 0
          tag_attr = key_options.collect { |p|
            if p.instance_of?(Hash)
              "#{p[:name]}=\"#{p[:value].gsub(/"/,'&quot;')}\""
            else
              count += 1
              "#{count}=\"#{p.gsub(/"/,'&quot;')}\""
            end
          }.join(" ")

          self.data = ret.blank? ? "" : "<template __name=\"#{key}\" __hash=\"#{key_digest}\" #{tag_attr}>#{ret}</template>"
          ""
        end
      end
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
# rubocop:enable Layout/SpaceAroundEqualsInParameterDefault
# rubocop:enable Style/HashSyntax
# rubocop:enable Layout/SpaceAfterComma
# rubocop:enable Style/RescueStandardError
# rubocop:enable Rails/Output
# rubocop:enable Style/MethodCallWithoutArgsParentheses
# rubocop:enable Layout/EmptyLinesAroundClassBody
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/PerceivedComplexity
# rubocop:enable Cop/LineBreakAroundConditionalBlock
# rubocop:enable Layout/EmptyLineAfterGuardClause
# rubocop:enable Performance/ReverseEach
# rubocop:enable Style/BlockDelimiters
# rubocop:enable Cop/LineBreakAroundConditionalBlock
# rubocop:enable Layout/MultilineBlockLayout
# rubocop:enable Layout/BlockEndNewline
