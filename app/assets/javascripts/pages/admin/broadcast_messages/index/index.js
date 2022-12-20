import initBroadcastMessages from '~/admin/broadcast_messages';
import initDeprecatedRemoveRowBehavior from '~/behaviors/deprecated_remove_row_behavior';
import initBroadcastMessagesForm from '../broadcast_message';

if (gon.features.vueBroadcastMessages) {
  initBroadcastMessages();
} else {
  initBroadcastMessagesForm();
  initDeprecatedRemoveRowBehavior();
}
