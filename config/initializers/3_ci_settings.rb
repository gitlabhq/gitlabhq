module Ci
  class Settings < Settingslogic
    source "#{Rails.root}/config/gitlab_ci.yml"
    namespace Rails.env

    class << self
      def gitlab_ci_on_non_standard_port?
        ![443, 80].include?(gitlab_ci.port.to_i)
      end

      private

      def build_gitlab_ci_url
        if gitlab_ci_on_non_standard_port?
          custom_port = ":#{gitlab_ci.port}"
        else
          custom_port = nil
        end
        [ gitlab_ci.protocol,
          "://",
          gitlab_ci.host,
          custom_port,
          gitlab_ci.relative_url_root
        ].join('')
      end
    end
  end
end


#
# GitlabCi
#
Ci::Settings['gitlab_ci'] ||= Settingslogic.new({})
Ci::Settings.gitlab_ci['https']               = false if Ci::Settings.gitlab_ci['https'].nil?
Ci::Settings.gitlab_ci['host']                ||= 'localhost'
Ci::Settings.gitlab_ci['port']                ||= Ci::Settings.gitlab_ci.https ? 443 : 80
Ci::Settings.gitlab_ci['relative_url_root']   ||= (ENV['RAILS_RELATIVE_URL_ROOT'] || '') + '/ci'
Ci::Settings.gitlab_ci['protocol']            ||= Ci::Settings.gitlab_ci.https ? "https" : "http"
Ci::Settings.gitlab_ci['email_from']          ||= "gitlab-ci@#{Ci::Settings.gitlab_ci.host}"
Ci::Settings.gitlab_ci['support_email']       ||= Ci::Settings.gitlab_ci.email_from
Ci::Settings.gitlab_ci['all_broken_builds']   = true if Ci::Settings.gitlab_ci['all_broken_builds'].nil?
Ci::Settings.gitlab_ci['add_pusher']          = false if Ci::Settings.gitlab_ci['add_pusher'].nil?
Ci::Settings.gitlab_ci['url']                 ||= Ci::Settings.send(:build_gitlab_ci_url)
Ci::Settings.gitlab_ci['builds_path']         = File.expand_path(Ci::Settings.gitlab_ci['builds_path'] || "builds/", Rails.root + '/ci')

# Compatibility with old config
Ci::Settings['gitlab_server_urls'] ||= Ci::Settings['allowed_gitlab_urls']

#
# Backup
#
Ci::Settings['backup'] ||= Settingslogic.new({})
Ci::Settings.backup['keep_time']  ||= 0
Ci::Settings.backup['path']         = File.expand_path(Ci::Settings.backup['path'] || "tmp/backups/", Rails.root)
Ci::Settings.backup['upload'] ||= Settingslogic.new({ 'remote_directory' => nil, 'connection' => nil })
# Convert upload connection settings to use symbol keys, to make Fog happy
if Ci::Settings.backup['upload']['connection']
  Ci::Settings.backup['upload']['connection'] = Hash[Ci::Settings.backup['upload']['connection'].map { |k, v| [k.to_sym, v] }]
end
Ci::Settings.backup['upload']['multipart_chunk_size'] ||= 104857600
