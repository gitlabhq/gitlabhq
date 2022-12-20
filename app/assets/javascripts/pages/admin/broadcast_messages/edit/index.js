import initEditBroadcastMessage from '~/admin/broadcast_messages/edit';
import initBroadcastMessagesForm from '../broadcast_message';

if (gon.features.vueBroadcastMessages) {
  initEditBroadcastMessage();
} else {
  initBroadcastMessagesForm();
}
