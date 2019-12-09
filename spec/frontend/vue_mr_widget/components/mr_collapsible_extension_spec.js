import { mount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import MrCollapsibleSection from '~/vue_merge_request_widget/components/mr_collapsible_extension.vue';

describe('Merge Request Collapsible Extension', () => {
  let wrapper;
  const data = {
    title: 'View artifacts',
  };

  const mountComponent = props => {
    wrapper = mount(MrCollapsibleSection, {
      propsData: {
        ...props,
      },
      slots: {
        default: '<div class="js-slot">Foo</div>',
      },
    });
  };

  const findTitle = () => wrapper.find('.js-title');
  const findErrorMessage = () => wrapper.find('.js-error-state');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('while collapsed', () => {
    beforeEach(() => {
      mountComponent(data);
    });

    it('renders provided title', () => {
      expect(findTitle().text()).toBe(data.title);
    });

    it('renders angle-right icon', () => {
      expect(wrapper.vm.arrowIconName).toBe('angle-right');
    });

    describe('onClick', () => {
      beforeEach(() => {
        wrapper.find('button').trigger('click');
      });

      it('rendes the provided slot', () => {
        expect(wrapper.find('.js-slot').isVisible()).toBe(true);
      });

      it('renders `Collapse` as the title', () => {
        expect(findTitle().text()).toBe('Collapse');
      });

      it('renders angle-down icon', () => {
        expect(wrapper.vm.arrowIconName).toBe('angle-down');
      });
    });
  });

  describe('while loading', () => {
    beforeEach(() => {
      mountComponent(Object.assign({}, data, { isLoading: true }));
    });

    it('renders the buttons disabled', () => {
      expect(
        wrapper
          .findAll('button')
          .at(0)
          .attributes('disabled'),
      ).toEqual('disabled');
      expect(
        wrapper
          .findAll('button')
          .at(1)
          .attributes('disabled'),
      ).toEqual('disabled');
    });

    it('renders loading spinner', () => {
      expect(wrapper.find(GlLoadingIcon).isVisible()).toBe(true);
    });
  });

  describe('with error', () => {
    beforeEach(() => {
      mountComponent(Object.assign({}, data, { hasError: true }));
    });

    it('does not render the buttons', () => {
      expect(wrapper.findAll('button').exists()).toBe(false);
    });

    it('renders title message provided', () => {
      expect(findErrorMessage().text()).toBe(data.title);
    });
  });
});
