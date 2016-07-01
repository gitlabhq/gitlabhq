class @AbuseReports
  MAX_MESSAGE_LENGTH = 300
  MESSAGE_CELL_SELECTOR = 'table tbody tr td:nth-child(3)'

  constructor: ->
    $(MESSAGE_CELL_SELECTOR).each @truncateLongMessage
    $(document).on 'click', "#{MESSAGE_CELL_SELECTOR}", @toggleMessageTruncation

  truncateLongMessage: ->
    messageCellElement = $(this)
    reportMessage = messageCellElement.text()
    if reportMessage.length > MAX_MESSAGE_LENGTH
      messageCellElement.attr 'data-original-message', reportMessage
      messageCellElement.attr 'data-message-truncated', 'true'
      messageCellElement.text "#{reportMessage.substr 0, MAX_MESSAGE_LENGTH}..."

  toggleMessageTruncation: ->
    messageCellElement = $(this)
    originalMessage = messageCellElement.attr 'data-original-message'
    return if not originalMessage
    if messageCellElement.attr('data-message-truncated') is 'true'
      messageCellElement.attr 'data-message-truncated', 'false'
      messageCellElement.text originalMessage
    else
      messageCellElement.attr 'data-message-truncated', 'true'
      messageCellElement.text "#{originalMessage.substr 0, MAX_MESSAGE_LENGTH}..."
