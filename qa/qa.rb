# frozen_string_literal: true

Encoding.default_external = 'UTF-8'

require_relative '../lib/gitlab_edition'
require_relative '../lib/gitlab/utils'
require_relative '../config/initializers/0_inject_enterprise_edition_module'

require_relative 'lib/gitlab'

require_relative '../config/bundler_setup'
Bundler.require(:default)

require 'securerandom'
require 'pathname'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/object/blank'
require 'rainbow/refinement'

require_relative 'qa/support/fips'

module QA
  root = "#{__dir__}/qa"

  loader = Zeitwerk::Loader.new

  # require jh/qa/qa.rb first, to load JH module make prepend module works
  require '../jh/qa/qa' if GitlabEdition.jh?

  loader.push_dir(root, namespace: QA)

  loader.ignore("#{root}/specs/features")
  loader.ignore("#{root}/specs/spec_helper.rb")

  loader.inflector.inflect(
    "ce" => "CE",
    "ee" => "EE",
    "api" => "API",
    "ssh" => "SSH",
    "ssh_key" => "SSHKey",
    "ssh_keys" => "SSHKeys",
    "ecdsa" => "ECDSA",
    "ed25519" => "ED25519",
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
    "saml_sso_sign_up" => "SamlSSOSignUp",
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
    "registry_with_cdn" => "RegistryWithCDN"
  )

  # Configure knapsack at the very begining of the setup
  loader.on_setup do
    QA::Support::KnapsackReport.configure!
  end

  loader.setup
end
