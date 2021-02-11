import { createConsumer } from '@rails/actioncable';
import ConnectionMonitor from './actioncable_connection_monitor';

const consumer = createConsumer();

if (consumer.connection) {
  consumer.connection.monitor = new ConnectionMonitor(consumer.connection);
}

export default consumer;
