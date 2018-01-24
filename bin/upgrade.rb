require_relative '../config/environment'

Gitlab::Upgrader.new.execute
