import $ from 'jquery';
import { setHTMLFixture } from 'helpers/fixtures';
import initSearch from '~/search_settings';
import { expandSection, closeSection } from '~/settings_panels';

jest.mock('~/settings_panels');

describe('search_settings/index', () => {
  let app;

  beforeEach(() => {
    const el = document.createElement('div');

    setHTMLFixture('<div id="content-body"></div>');

    app = initSearch({ el });
  });

  afterEach(() => {
    app.$destroy();
  });

  it('calls settings_panel.onExpand when expand event is emitted', () => {
    const section = { name: 'section' };
    app.$refs.searchSettings.$emit('expand', section);

    expect(expandSection).toHaveBeenCalledWith($(section));
  });

  it('calls settings_panel.closeSection when collapse event is emitted', () => {
    const section = { name: 'section' };
    app.$refs.searchSettings.$emit('collapse', section);

    expect(closeSection).toHaveBeenCalledWith($(section));
  });
});
