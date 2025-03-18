import { mountExtended } from 'helpers/vue_test_utils_helper';
import ImportByUrlForm from '~/projects/new_v2/components/import_by_url_form.vue';

describe('Import Project by URL Form', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mountExtended(ImportByUrlForm);
  };

  beforeEach(() => {
    createComponent();
  });

  const findNextButton = () => wrapper.findByTestId('import-project-by-url-next-button');
  const findBackButton = () => wrapper.findByTestId('import-project-by-url-back-button');

  it('renders the option to move to Next Step', () => {
    expect(findNextButton().text()).toBe('Next step');
  });

  it(`emits the "back" event when the back button is clicked`, () => {
    findBackButton().trigger('click');
    expect(wrapper.emitted('back')).toHaveLength(1);
  });
});
