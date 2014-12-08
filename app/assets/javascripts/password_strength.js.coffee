#= require pwstrength-bootstrap-1.2.2
overwritten_messages =
  wordSimilarToUsername: "Your password should not contain your username"

overwritten_rules =
  wordSequences: false

options =
  showProgressBar: false
  showVerdicts: false
  showPopover: true
  showErrors: true
  showStatus: true
  errorMessages: overwritten_messages
  
$(document).ready ->
  profileOptions = {}
  profileOptions.ui = options
  profileOptions.rules =
    activated: overwritten_rules

  deviseOptions = {}
  deviseOptions.common =
    usernameField: "#user_username"
  deviseOptions.ui = options
  deviseOptions.rules =
    activated: overwritten_rules

  $("#user_password_profile").pwstrength profileOptions
  $("#user_password_sign_up").pwstrength deviseOptions
  $("#user_password_recover").pwstrength deviseOptions
