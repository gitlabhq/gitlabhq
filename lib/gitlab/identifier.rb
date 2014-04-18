# Detect user based on identifier like
# key-13 or user-36 or last commit
module Gitlab
  module Identifier
    def identify(identifier, project, newrev)
      if identifier.blank?
        # Local push from gitlab
        email = project.repository.commit(newrev).author_email rescue nil
        User.find_by(email: email) if email

      elsif identifier =~ /\Auser-\d+\Z/
        # git push over http
        user_id = identifier.gsub("user-", "")
        User.find_by(id: user_id)

      elsif identifier =~ /\Akey-\d+\Z/
        # git push over ssh
        key_id = identifier.gsub("key-", "")
        Key.find_by(id: key_id).try(:user)
      end
    end
  end
end
