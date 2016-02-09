class AddPagesCustomDomainToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :pages_custom_certificate, :text
    add_column :projects, :encrypted_pages_custom_certificate_key, :text
    add_column :projects, :encrypted_pages_custom_certificate_key_iv, :string
    add_column :projects, :encrypted_pages_custom_certificate_key_salt, :string
    add_column :projects, :pages_custom_domain, :string, unique: true
    add_column :projects, :pages_redirect_http, :boolean, default: false, null: false
  end
end
