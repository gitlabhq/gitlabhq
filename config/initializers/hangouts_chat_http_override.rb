# frozen_string_literal: true

HangoutsChat::Sender::HTTP.prepend(Gitlab::Patch::HangoutsChatHTTPOverride)
