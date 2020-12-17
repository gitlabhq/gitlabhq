# frozen_string_literal: true

class UserEntity < API::Entities::UserPath
end

UserEntity.prepend_if_ee('EE::UserEntity')
