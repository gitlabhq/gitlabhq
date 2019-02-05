# frozen_string_literal: true

Sprockets::Base.prepend(Gitlab::Patch::SprocketsBaseFileDigestKey)
