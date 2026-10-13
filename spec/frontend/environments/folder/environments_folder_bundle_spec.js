import { createWrapper } from '@vue/test-utils';
import initEnvironmentsFolder from '~/environments/folder/environments_folder_bundle';
import setWindowLocation from 'helpers/set_window_location_helper';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/environments/graphql/client', () => ({
  apolloProvider: jest.fn(),
}));

jest.mock('~/environments/folder/environments_folder_app.vue', () => ({
  name: 'EnvironmentsFolderApp',
  props: ['scope'],
  render(h) {
    return h('div', this.scope);
  },
}));

describe('environments folder router', () => {
  let vm;
  let wrapper;

  beforeEach(() => {
    document.body.innerHTML =
      '<div id="environments-folder-list-view" data-endpoint="/environments/folders/review.json" data-folder-name="review"></div>';
  });

  afterEach(() => {
    vm?.$destroy();
    document.body.innerHTML = '';
  });

  describe.each([
    ['', 'active'],
    ['?scope=', 'active'],
    ['?scope=active', 'active'],
    ['?scope=stopped', 'stopped'],
  ])('with query %s', (search, scope) => {
    beforeEach(async () => {
      setWindowLocation(`/${search}`);
      vm = initEnvironmentsFolder();
      wrapper = createWrapper(vm);
      await waitForPromises();
    });

    it('renders the folder with the expected scope', () => {
      expect(wrapper.text()).toBe(scope);
    });
  });
});
