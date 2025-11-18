import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GenerateTokenApp from '~/vue_shared/access_tokens/components/fine_grained_tokens/generate_token_app.vue';
import PageHeading from '~/vue_shared/components/page_heading.vue';

describe('Generate Token app', () => {
  let wrapper;

  const createWrapper = () => {
    wrapper = shallowMountExtended(GenerateTokenApp);
  };

  const findPageHeading = () => wrapper.findComponent(PageHeading);

  beforeEach(() => createWrapper());

  it('shows page header', () => {
    expect(findPageHeading().props('heading')).toBe('Generate fine-grained token');
  });

  it('shows page header description', () => {
    expect(findPageHeading().text()).toBe(
      'Fine-grained personal access tokens give you granular control over the specific resources and actions available to the token.',
    );
  });
});
