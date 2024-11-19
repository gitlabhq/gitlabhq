import { GlModal, GlSprintf } from '@gitlab/ui';
import AmbiguousRefModal from '~/ref/components/ambiguous_ref_modal.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
import { visitUrl } from '~/lib/utils/url_utility';
import { TEST_HOST } from 'spec/test_constants';

jest.mock('~/lib/utils/url_utility');

describe('AmbiguousRefModal component', () => {
  let wrapper;
  const showModalSpy = jest.fn();

  const createComponent = () => {
    wrapper = shallowMountExtended(AmbiguousRefModal, {
      propsData: { refName: 'main' },
      stubs: {
        GlModal: stubComponent(GlModal, {
          methods: {
            show: showModalSpy,
          },
          template: RENDER_ALL_SLOTS_TEMPLATE,
        }),
        GlSprintf,
      },
    });
  };

  beforeEach(() => createComponent());

  const findModal = () => wrapper.findComponent(GlModal);
  const findViewTagButton = () => wrapper.findByTestId('view-tag-btn');
  const findViewBranchButton = () => wrapper.findByTestId('view-branch-btn');

  it('renders a GlModal component with the correct props', () => {
    expect(showModalSpy).toHaveBeenCalled();
    expect(findModal().props('title')).toBe('Which reference do you want to view?');
  });

  it('renders a description', () => {
    expect(wrapper.text()).toContain('There is a branch and a tag with the same name of main.');
    expect(wrapper.text()).toContain('Which reference would you like to view?');
  });

  it('renders action buttons', () => {
    expect(findViewTagButton().exists()).toBe(true);
    expect(findViewBranchButton().exists()).toBe(true);
  });

  describe('when clicking the action buttons', () => {
    it('redirects to the tag ref when tag button is clicked', () => {
      findViewTagButton().vm.$emit('click');

      expect(visitUrl).toHaveBeenCalledWith(`${TEST_HOST}/?ref_type=tags`);
    });

    it('redirects to the branch ref when branch button is clicked', () => {
      findViewBranchButton().vm.$emit('click');

      expect(visitUrl).toHaveBeenCalledWith(`${TEST_HOST}/?ref_type=heads`);
    });
  });
});
