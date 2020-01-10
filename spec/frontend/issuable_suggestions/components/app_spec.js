import { shallowMount } from '@vue/test-utils';
import App from '~/issuable_suggestions/components/app.vue';
import Suggestion from '~/issuable_suggestions/components/item.vue';

describe('Issuable suggestions app component', () => {
  let wrapper;

  function createComponent(search = 'search') {
    wrapper = shallowMount(App, {
      propsData: {
        search,
        projectPath: 'project',
      },
      attachToDocument: true,
    });
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('does not render with empty search', () => {
    wrapper.setProps({ search: '' });

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.isVisible()).toBe(false);
    });
  });

  describe('with data', () => {
    let data;

    beforeEach(() => {
      data = { issues: [{ id: 1 }, { id: 2 }] };
    });

    it('renders component', () => {
      wrapper.setData(data);

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.isEmpty()).toBe(false);
      });
    });

    it('does not render with empty search', () => {
      wrapper.setProps({ search: '' });
      wrapper.setData(data);

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.isVisible()).toBe(false);
      });
    });

    it('does not render when loading', () => {
      wrapper.setData({
        ...data,
        loading: 1,
      });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.isVisible()).toBe(false);
      });
    });

    it('does not render with empty issues data', () => {
      wrapper.setData({ issues: [] });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.isVisible()).toBe(false);
      });
    });

    it('renders list of issues', () => {
      wrapper.setData(data);

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.findAll(Suggestion).length).toBe(2);
      });
    });

    it('adds margin class to first item', () => {
      wrapper.setData(data);

      return wrapper.vm.$nextTick(() => {
        expect(
          wrapper
            .findAll('li')
            .at(0)
            .is('.append-bottom-default'),
        ).toBe(true);
      });
    });

    it('does not add margin class to last item', () => {
      wrapper.setData(data);

      return wrapper.vm.$nextTick(() => {
        expect(
          wrapper
            .findAll('li')
            .at(1)
            .is('.append-bottom-default'),
        ).toBe(false);
      });
    });
  });
});
