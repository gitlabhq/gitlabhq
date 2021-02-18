import { setHTMLFixture } from 'helpers/fixtures';
import mount from '~/search_settings/mount';
import { expandSection, closeSection } from '~/settings_panels';

jest.mock('~/settings_panels');

describe('search_settings/mount', () => {
  let app;

  beforeEach(() => {
    const el = document.createElement('div');

    setHTMLFixture('<div id="content-body"></div>');

    app = mount({ el });
  });

  afterEach(() => {
    app.$destroy();
  });

  it('calls settings_panel.onExpand when expand event is emitted', () => {
    const section = { name: 'section' };
    app.$refs.searchSettings.$emit('expand', section);

    expect(expandSection).toHaveBeenCalledWith(section);
  });

  it('calls settings_panel.closeSection when collapse event is emitted', () => {
    const section = { name: 'section' };
    app.$refs.searchSettings.$emit('collapse', section);

    expect(closeSection).toHaveBeenCalledWith(section);
  });
});
