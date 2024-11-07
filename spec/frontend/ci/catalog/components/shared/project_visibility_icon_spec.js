import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ProjectVisibilityIcon from '~/ci/catalog/components/shared/project_visibility_icon.vue';

describe('Project Visibility Icon', () => {
  let wrapper;

  const findVisibilityIcon = () => wrapper.findComponent(GlIcon);

  const createComponent = (props = {}) => {
    wrapper = extendedWrapper(
      shallowMount(ProjectVisibilityIcon, {
        propsData: {
          ...props,
        },
      }),
    );
  };

  describe('on render', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the icon', () => {
      expect(findVisibilityIcon().exists()).toBe(true);
    });

    it('has the correct icon name', () => {
      expect(findVisibilityIcon().attributes().name).toBe('lock');
    });

    it('has the correct tooltip', () => {
      expect(findVisibilityIcon().attributes().title).toBe(
        'Private - This component project can only be viewed by project members.',
      );
    });
  });
});
