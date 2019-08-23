# frozen_string_literal: true

ChronicDuration.raise_exceptions = true

ChronicDuration.prepend Gitlab::Patch::ChronicDuration
