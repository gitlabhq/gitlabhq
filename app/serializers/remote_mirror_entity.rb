# frozen_string_literal: true

class RemoteMirrorEntity < Grape::Entity
  expose :id
  expose :safe_url, as: :url
  expose :enabled

  expose :auth_method
  expose :ssh_known_hosts
  expose :ssh_public_key

  expose :ssh_known_hosts_fingerprints do |remote_mirror|
    remote_mirror.ssh_known_hosts_fingerprints.as_json
  end
end

RemoteMirrorEntity.prepend_mod
