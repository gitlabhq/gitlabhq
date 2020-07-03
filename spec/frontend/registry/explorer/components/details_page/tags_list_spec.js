import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import component from '~/registry/explorer/components/details_page/tags_list.vue';
import TagsListRow from '~/registry/explorer/components/details_page/tags_list_row.vue';
import { TAGS_LIST_TITLE, REMOVE_TAGS_BUTTON_TITLE } from '~/registry/explorer/constants/index';
import { tagsListResponse } from '../../mock_data';

describe('Tags List', () => {
  let wrapper;
  const tags = [...tagsListResponse.data];

  const findTagsListRow = () => wrapper.findAll(TagsListRow);
  const findDeleteButton = () => wrapper.find(GlButton);
  const findListTitle = () => wrapper.find('[data-testid="list-title"]');

  const mountComponent = (propsData = { tags, isDesktop: true }) => {
    wrapper = shallowMount(component, {
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('List title', () => {
    it('exists', () => {
      mountComponent();

      expect(findListTitle().exists()).toBe(true);
    });

    it('has the correct text', () => {
      mountComponent();

      expect(findListTitle().text()).toBe(TAGS_LIST_TITLE);
    });
  });

  describe('delete button', () => {
    it('is not shown on mobile view', () => {
      mountComponent({ tags, isDesktop: false });

      expect(findDeleteButton().exists()).toBe(false);
    });

    it('is shown on desktop view', () => {
      mountComponent();

      expect(findDeleteButton().exists()).toBe(true);
    });

    it('has the correct text', () => {
      mountComponent();

      expect(findDeleteButton().text()).toBe(REMOVE_TAGS_BUTTON_TITLE);
    });

    it('has the correct props', () => {
      mountComponent();

      expect(findDeleteButton().attributes()).toMatchObject({
        category: 'secondary',
        variant: 'danger',
      });
    });

    it('is disabled when no item is selected', () => {
      mountComponent();

      expect(findDeleteButton().attributes('disabled')).toBe('true');
    });

    it('is enabled when at least one item is selected', async () => {
      mountComponent();
      findTagsListRow()
        .at(0)
        .vm.$emit('select');
      await wrapper.vm.$nextTick();
      expect(findDeleteButton().attributes('disabled')).toBe(undefined);
    });

    it('click event emits a deleted event with selected items', () => {
      mountComponent();
      findTagsListRow()
        .at(0)
        .vm.$emit('select');

      findDeleteButton().vm.$emit('click');
      expect(wrapper.emitted('delete')).toEqual([[{ centos6: true }]]);
    });
  });

  describe('list rows', () => {
    it('one row exist for each tag', () => {
      mountComponent();

      expect(findTagsListRow()).toHaveLength(tags.length);
    });

    it('the correct props are bound to it', () => {
      mountComponent();

      const rows = findTagsListRow();

      expect(rows.at(0).attributes()).toMatchObject({
        first: 'true',
        isdesktop: 'true',
      });

      // The list has only two tags and for some reasons .at(-1) does not work
      expect(rows.at(1).attributes()).toMatchObject({
        last: 'true',
        isdesktop: 'true',
      });
    });

    describe('events', () => {
      it('select event update the selected items', async () => {
        mountComponent();
        findTagsListRow()
          .at(0)
          .vm.$emit('select');
        await wrapper.vm.$nextTick();
        expect(
          findTagsListRow()
            .at(0)
            .attributes('selected'),
        ).toBe('true');
      });

      it('delete event emit a delete event', () => {
        mountComponent();
        findTagsListRow()
          .at(0)
          .vm.$emit('delete');
        expect(wrapper.emitted('delete')).toEqual([[{ centos6: true }]]);
      });
    });
  });
});
