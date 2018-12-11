# frozen_string_literal: true

class RemoteMirrorEntity < Grape::Entity
  expose :id
  expose :url
  expose :enabled

  expose :auth_method
  expose :ssh_known_hosts
  expose :ssh_public_key

  expose :ssh_known_hosts_fingerprints do |remote_mirror|
    remote_mirror.ssh_known_hosts_fingerprints.as_json
  end
end
