class EncryptVariables < ActiveRecord::Migration
  def up
    Variable.find_each do |variable|
      variable.update(value: variable.read_attribute(:value)) unless variable.encrypted_value
    end
  end

  def down
  end
end
