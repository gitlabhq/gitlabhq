import { GlTabsBehavior } from '~/tabs';

const tabNavs = document.querySelectorAll('.js-o11y-endpoint-tabs, .js-o11y-curl-tabs');
tabNavs.forEach((el) => new GlTabsBehavior(el));
