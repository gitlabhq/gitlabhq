# frozen_string_literal: true

Encoding.default_external = 'UTF-8'

require 'gitlab/utils/all'

require_relative '../lib/gitlab_edition'
require_relative '../config/initializers/0_inject_enterprise_edition_module'

require_relative '../config/bundler_setup'
Bundler.require(:default)

require 'securerandom'
require 'pathname'
require 'rainbow/refinement'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/module/delegation'
require 'active_support/parameter_filter'
module QA
  root = "#{__dir__}/qa"

  loader = Zeitwerk::Loader.new

  # require jh/qa/qa.rb first, to load JH module make prepend module works
  require '../jh/qa/qa' if GitlabEdition.jh?

  loader.push_dir(root, namespace: QA)

  loader.ignore("#{root}/factories")
  loader.ignore("#{root}/specs/features")
  loader.ignore("#{root}/specs/spec_helper.rb")

  # we need to eager load scenario classes
  # zeitwerk does not have option to configure what to eager load, so all exceptions have to be defined
  loader.do_not_eager_load("#{root}/ce")
  loader.do_not_eager_load("#{root}/ee")
  loader.do_not_eager_load("#{root}/flow")
  loader.do_not_eager_load("#{root}/git")
  loader.do_not_eager_load("#{root}/mobile")
  loader.do_not_eager_load("#{root}/page")
  loader.do_not_eager_load("#{root}/resource")
  loader.do_not_eager_load("#{root}/runtime")
  loader.do_not_eager_load("#{root}/service")
  loader.do_not_eager_load("#{root}/specs")
  loader.do_not_eager_load("#{root}/support")
  loader.do_not_eager_load("#{root}/tools")
  loader.do_not_eager_load("#{root}/vendor")

  loader.inflector.inflect(
    "ce" => "CE",
    "ee" => "EE",
    "api" => "API",
    "ssh" => "SSH",
    "ssh_key" => "SSHKey",
    "ssh_keys" => "SSHKeys",
    "ecdsa" => "ECDSA",
    "ed25519" => "ED25519",
    "graphql" => "GraphQL",
    "rsa" => "RSA",
    "ldap" => "LDAP",
    "ldap_tls" => "LDAPTLS",
    "ldap_no_tls" => "LDAPNoTLS",
    "ldap_no_server" => "LDAPNoServer",
    "rspec" => "RSpec",
    "web_ide" => "WebIDE",
    "ci_cd" => "CiCd",
    "project_imported_from_url" => "ProjectImportedFromURL",
    "repo_by_url" => "RepoByURL",
    "oauth" => "OAuth",
    "saml_sso_sign_in" => "SamlSSOSignIn",
    "group_saml" => "GroupSAML",
    "instance_saml" => "InstanceSAML",
    "saml_sso" => "SamlSSO",
    "ldap_sync" => "LDAPSync",
    "ip_address" => "IPAddress",
    "gpg" => "GPG",
    "user_gpg" => "UserGPG",
    "smtp" => "SMTP",
    "otp" => "OTP",
    "jira_api" => "JiraAPI",
    "registry_tls" => "RegistryTLS",
    "jetbrains" => "JetBrains",
    "vscode" => "VSCode",
    "registry_with_cdn" => "RegistryWithCDN",
    "fips" => "FIPS",
    "ci_cd_settings" => "CICDSettings",
    "cli" => "CLI",
    "import_with_smtp" => "ImportWithSMTP"
  )

  loader.setup
  loader.eager_load
end

# Custom warning processing
Warning.process do |warning|
  QA::Runtime::Logger.warn(warning.strip)
end

# ignore faraday-multipart warning produced by octokit as it is only required for functionality we don't use
# see: https://github.com/octokit/octokit.rb/issues/1701
Warning.ignore(/To use multipart middleware with Faraday v2\.0/)
require "octokit"

# TODO: Temporary monkeypatch for broadcast logging
# Remove once activesupport is upgraded to 7.1
module Gitlab
  module QA
    class TestLogger
      # Combined logger instance
      #
      # @param [<Symbol, String>] level
      # @param [String] source
      # @return [ActiveSupport::Logger]
      def self.logger(level: :info, source: 'Gitlab QA', path: 'tmp')
        console_log = console_logger(level: level, source: source)
        file_log = file_logger(source: source, path: path)

        console_log.extend(ActiveSupport::Logger.broadcast(file_log))
      end
    end
  end
end
