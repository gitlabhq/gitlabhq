xml.instruct!
xml.sparkleshare {
  xml.invite {
    xml.address @invite.address
    xml.remote_path @invite.remote_path
    xml.fingerprint @invite.fingerprint if @invite.fingerprint
    xml.accept_url(sparkle_share_accept_invite_url(token: @invite.token))
    xml.announcements_url(@invite.announcements_url) if @invite.announcements_url
  }
}
