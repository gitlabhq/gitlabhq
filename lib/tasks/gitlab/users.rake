namespace :gitlab do
  namespace :users do
    desc "GitLab | Clear the authentication token for all users"
    task clear_all_authentication_tokens: :environment  do |t, args|
      # Do small batched updates because these updates will be slow and locking
      User.select(:id).find_in_batches(batch_size: 100) do |batch|
        User.where(id: batch.map(&:id)).update_all(authentication_token: nil)
      end
    end
  end
end
