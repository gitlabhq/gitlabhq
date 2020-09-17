import { shallowMount } from '@vue/test-utils';
import { GlLink, GlLabel } from '@gitlab/ui';

import IssuableItem from '~/issuable_list/components/issuable_item.vue';

import { mockIssuable, mockRegularLabel, mockScopedLabel } from '../mock_data';

const createComponent = ({ issuableSymbol = '#', issuable = mockIssuable } = {}) =>
  shallowMount(IssuableItem, {
    propsData: {
      issuableSymbol,
      issuable,
    },
  });

describe('IssuableItem', () => {
  const mockLabels = mockIssuable.labels.nodes;
  const mockAuthor = mockIssuable.author;
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('author', () => {
      it('returns `issuable.author` reference', () => {
        expect(wrapper.vm.author).toEqual(mockIssuable.author);
      });
    });

    describe('authorId', () => {
      it.each`
        authorId                 | returnValue
        ${1}                     | ${1}
        ${'1'}                   | ${1}
        ${'gid://gitlab/User/1'} | ${'1'}
        ${'foo'}                 | ${''}
      `(
        'returns $returnValue when value of `issuable.author.id` is $authorId',
        async ({ authorId, returnValue }) => {
          wrapper.setProps({
            issuable: {
              ...mockIssuable,
              author: {
                ...mockAuthor,
                id: authorId,
              },
            },
          });

          await wrapper.vm.$nextTick();

          expect(wrapper.vm.authorId).toBe(returnValue);
        },
      );
    });

    describe('labels', () => {
      it('returns `issuable.labels.nodes` reference when it is available', () => {
        expect(wrapper.vm.labels).toEqual(mockLabels);
      });

      it('returns `issuable.labels` reference when it is available', async () => {
        wrapper.setProps({
          issuable: {
            ...mockIssuable,
            labels: mockLabels,
          },
        });

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.labels).toEqual(mockLabels);
      });

      it('returns empty array when none of `issuable.labels.nodes` or `issuable.labels` are available', async () => {
        wrapper.setProps({
          issuable: {
            ...mockIssuable,
            labels: null,
          },
        });

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.labels).toEqual([]);
      });
    });

    describe('createdAt', () => {
      it('returns string containing timeago string based on `issuable.createdAt`', () => {
        expect(wrapper.vm.createdAt).toContain('created');
        expect(wrapper.vm.createdAt).toContain('ago');
      });
    });

    describe('updatedAt', () => {
      it('returns string containing timeago string based on `issuable.updatedAt`', () => {
        expect(wrapper.vm.updatedAt).toContain('updated');
        expect(wrapper.vm.updatedAt).toContain('ago');
      });
    });
  });

  describe('methods', () => {
    describe('scopedLabel', () => {
      it.each`
        label               | labelType    | returnValue
        ${mockRegularLabel} | ${'regular'} | ${false}
        ${mockScopedLabel}  | ${'scoped'}  | ${true}
      `(
        'return $returnValue when provided label param is a $labelType label',
        ({ label, returnValue }) => {
          expect(wrapper.vm.scopedLabel(label)).toBe(returnValue);
        },
      );
    });
  });

  describe('template', () => {
    it('renders issuable title', () => {
      const titleEl = wrapper.find('[data-testid="issuable-title"]');

      expect(titleEl.exists()).toBe(true);
      expect(titleEl.find(GlLink).attributes('href')).toBe(mockIssuable.webUrl);
      expect(titleEl.find(GlLink).text()).toBe(mockIssuable.title);
    });

    it('renders issuable reference', () => {
      const referenceEl = wrapper.find('[data-testid="issuable-reference"]');

      expect(referenceEl.exists()).toBe(true);
      expect(referenceEl.text()).toBe(`#${mockIssuable.iid}`);
    });

    it('renders issuable createdAt info', () => {
      const createdAtEl = wrapper.find('[data-testid="issuable-created-at"]');

      expect(createdAtEl.exists()).toBe(true);
      expect(createdAtEl.attributes('title')).toBe('Jun 29, 2020 1:52pm GMT+0000');
      expect(createdAtEl.text()).toBe(wrapper.vm.createdAt);
    });

    it('renders issuable author info', () => {
      const authorEl = wrapper.find('[data-testid="issuable-author"]');

      expect(authorEl.exists()).toBe(true);
      expect(authorEl.attributes()).toMatchObject({
        'data-user-id': wrapper.vm.authorId,
        'data-username': mockAuthor.username,
        'data-name': mockAuthor.name,
        'data-avatar-url': mockAuthor.avatarUrl,
        href: mockAuthor.webUrl,
      });
      expect(authorEl.text()).toBe(mockAuthor.name);
    });

    it('renders gl-label component for each label present within `issuable` prop', () => {
      const labelsEl = wrapper.findAll(GlLabel);

      expect(labelsEl.exists()).toBe(true);
      expect(labelsEl).toHaveLength(mockLabels.length);
      expect(labelsEl.at(0).props()).toMatchObject({
        backgroundColor: mockLabels[0].color,
        title: mockLabels[0].title,
        description: mockLabels[0].description,
        scoped: false,
        size: 'sm',
      });
    });

    it('renders issuable updatedAt info', () => {
      const updatedAtEl = wrapper.find('[data-testid="issuable-updated-at"]');

      expect(updatedAtEl.exists()).toBe(true);
      expect(updatedAtEl.find('span').attributes('title')).toBe('Sep 10, 2020 11:41am GMT+0000');
      expect(updatedAtEl.text()).toBe(wrapper.vm.updatedAt);
    });
  });
});
