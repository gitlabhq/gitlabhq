import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import YourWorkProjectsApp from '~/projects/your_work/components/app.vue';

jest.mock('~/alert');

describe('YourWorkProjectsApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(YourWorkProjectsApp);
  };

  const findPageText = () => wrapper.find('p');

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders Vue app with Projects list p tag', () => {
      expect(findPageText().text()).toBe('Projects list');
    });
  });
});
