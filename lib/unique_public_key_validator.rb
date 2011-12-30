class UniquePublicKeyValidator < ActiveModel::Validator
  def validate(record)
    if (DeployKey.where('key = ? AND id !=?', record.key , record.id).count > 0 || Key.where('key = ? AND id !=?', record.key , record.id).count > 0)
      record.errors.add :key, 'already exist.'
    end
  end
end
