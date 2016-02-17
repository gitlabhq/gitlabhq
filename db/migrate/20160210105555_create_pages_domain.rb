class CreatePagesDomain < ActiveRecord::Migration
  def change
    create_table :pages_domains do |t|
      t.integer :project_id
      t.text    :certificate
      t.text    :encrypted_key
      t.string  :encrypted_key_iv
      t.string  :encrypted_key_salt
      t.string  :domain
    end

    add_index :pages_domains, :domain, unique: true
  end
end
