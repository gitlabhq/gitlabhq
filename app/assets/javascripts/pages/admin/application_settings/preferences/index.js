import { initSimpleApp } from '~/helpers/init_simple_app_helper';
import TimezoneDropdown from '~/vue_shared/components/timezone_dropdown/timezone_dropdown.vue';

initSimpleApp('.js-timezone-dropdown', TimezoneDropdown, { name: 'TimezoneDropdownRoot' });
