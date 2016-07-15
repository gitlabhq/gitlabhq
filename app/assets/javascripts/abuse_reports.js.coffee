class @AbuseReports
  MAX_MESSAGE_LENGTH = 300
  MESSAGE_CELL_SELECTOR = '.abuse-reports td:nth-child(3)'

  constructor: ->
    $(MESSAGE_CELL_SELECTOR).each @truncateLongMessage
    $(document)
      .off 'click', MESSAGE_CELL_SELECTOR
      .on 'click', MESSAGE_CELL_SELECTOR, @toggleMessageTruncation

  truncateLongMessage: ->
    $messageCellElement = $(this)
    reportMessage = $messageCellElement.text()
    if reportMessage.length > MAX_MESSAGE_LENGTH
      $messageCellElement.data 'original-message', reportMessage
      $messageCellElement.data 'message-truncated', 'true'
      $messageCellElement.text "#{reportMessage.substr 0, MAX_MESSAGE_LENGTH}..."

  toggleMessageTruncation: ->
    $messageCellElement = $(this)
    originalMessage = $messageCellElement.data 'original-message'
    return if not originalMessage
    if $messageCellElement.data('message-truncated') is 'true'
      $messageCellElement.data 'message-truncated', 'false'
      $messageCellElement.text originalMessage
    else
      $messageCellElement.data 'message-truncated', 'true'
      $messageCellElement.text "#{originalMessage.substr 0, MAX_MESSAGE_LENGTH}..."
