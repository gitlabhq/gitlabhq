import './polyfills';
import './bootstrap';
import './vue';
import './gitlab_ui';
import '../lib/utils/axios_utils';
import { openUserCountsBroadcast } from './nav/user_merge_requests';

openUserCountsBroadcast();
