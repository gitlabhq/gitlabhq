import Vuex from 'vuex';
import $ from 'jquery';
import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Dropdown from '~/ide/components/file_templates/dropdown.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('IDE file templates dropdown component', () => {
  let wrapper;
  let element;
  let fetchTemplateTypesMock;

  const defaultProps = {
    label: 'label',
  };

  const findItemButtons = () => wrapper.findAll('button');
  const findSearch = () => wrapper.find('input[type="search"]');
  const triggerDropdown = () => $(element).trigger('show.bs.dropdown');

  const createComponent = ({ props, state } = {}) => {
    fetchTemplateTypesMock = jest.fn();
    const fakeStore = new Vuex.Store({
      modules: {
        fileTemplates: {
          namespaced: true,
          state: {
            templates: [],
            isLoading: false,
            ...state,
          },
          actions: {
            fetchTemplateTypes: fetchTemplateTypesMock,
          },
        },
      },
    });

    wrapper = shallowMount(Dropdown, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      store: fakeStore,
      localVue,
      sync: false,
    });

    ({ element } = wrapper);
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('calls clickItem on click', () => {
    const itemData = { name: 'test.yml ' };
    createComponent({ props: { data: [itemData] } });
    const item = findItemButtons().at(0);
    item.trigger('click');

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.emitted().click[0][0]).toBe(itemData);
    });
  });

  it('renders dropdown title', () => {
    const title = 'Test title';
    createComponent({ props: { title } });

    expect(wrapper.find('.dropdown-title').text()).toContain(title);
  });

  describe('in async mode', () => {
    const defaultAsyncProps = { ...defaultProps, isAsyncData: true };

    it('calls `fetchTemplateTypes` on dropdown event', () => {
      createComponent({ props: defaultAsyncProps });

      triggerDropdown();

      expect(fetchTemplateTypesMock).toHaveBeenCalled();
    });

    it('does not call `fetchTemplateTypes` on dropdown event if destroyed', () => {
      createComponent({ props: defaultAsyncProps });
      wrapper.destroy();

      triggerDropdown();

      expect(fetchTemplateTypesMock).not.toHaveBeenCalled();
    });

    it('shows loader when isLoading is true', () => {
      createComponent({ props: defaultAsyncProps, state: { isLoading: true } });

      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
    });

    it('renders templates', () => {
      const templates = [{ name: 'file-1' }, { name: 'file-2' }];
      createComponent({
        props: { ...defaultAsyncProps, data: [{ name: 'should-never-appear ' }] },
        state: {
          templates,
        },
      });
      const items = findItemButtons();

      expect(items.wrappers.map(x => x.text())).toEqual(templates.map(x => x.name));
    });

    it('searches template data', () => {
      const templates = [{ name: 'match 1' }, { name: 'other' }, { name: 'match 2' }];
      const matches = ['match 1', 'match 2'];
      createComponent({
        props: { ...defaultAsyncProps, data: matches, searchable: true },
        state: { templates },
      });
      findSearch().setValue('match');
      return wrapper.vm.$nextTick().then(() => {
        const items = findItemButtons();

        expect(items.length).toBe(matches.length);
        expect(items.wrappers.map(x => x.text())).toEqual(matches);
      });
    });

    it('does not render input when `searchable` is true & `showLoading` is true', () => {
      createComponent({
        props: { ...defaultAsyncProps, searchable: true },
        state: { isLoading: true },
      });

      expect(findSearch().exists()).toBe(false);
    });
  });

  describe('in sync mode', () => {
    it('renders props data', () => {
      const data = [{ name: 'file-1' }, { name: 'file-2' }];
      createComponent({
        props: { data },
        state: {
          templates: [{ name: 'should-never-appear ' }],
        },
      });

      const items = findItemButtons();

      expect(items.length).toBe(data.length);
      expect(items.wrappers.map(x => x.text())).toEqual(data.map(x => x.name));
    });

    it('renders input when `searchable` is true', () => {
      createComponent({ props: { searchable: true } });

      expect(findSearch().exists()).toBe(true);
    });

    it('searches data', () => {
      const data = [{ name: 'match 1' }, { name: 'other' }, { name: 'match 2' }];
      const matches = ['match 1', 'match 2'];
      createComponent({ props: { searchable: true, data } });
      findSearch().setValue('match');
      return wrapper.vm.$nextTick().then(() => {
        const items = findItemButtons();

        expect(items.length).toBe(matches.length);
        expect(items.wrappers.map(x => x.text())).toEqual(matches);
      });
    });
  });
});
