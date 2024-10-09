import { GlPaginatedList } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import PaginatedList from '~/vue_shared/components/paginated_list.vue';
import { PREV, NEXT } from '~/vue_shared/components/pagination/constants';

describe('Pagination links component', () => {
  let wrapper;
  let glPaginatedList;

  const template = `
    <template #default="{ listItem }">
      <div class="slot">
        <span class="item">Item Name: {{ listItem.id }}</span>
      </div>
    </template>
  `;

  const props = {
    prevText: PREV,
    nextText: NEXT,
  };

  beforeEach(() => {
    wrapper = mount(PaginatedList, {
      scopedSlots: {
        default: template,
      },
      propsData: {
        list: [{ id: 'foo' }, { id: 'bar' }],
        props,
      },
    });

    [glPaginatedList] = wrapper.vm.$children;
  });
  const findGlPaginatedList = () => wrapper.findComponent(GlPaginatedList);

  describe('Paginated List Component', () => {
    describe('props', () => {
      // We test attrs and not props because we pass through to child component using v-bind:"$attrs"
      it('should pass prevText to GitLab UI paginated list', () => {
        expect(glPaginatedList.$attrs['prev-text']).toBe(props.prevText);
      });
      it('should pass nextText to GitLab UI paginated list', () => {
        expect(glPaginatedList.$attrs['next-text']).toBe(props.nextText);
      });
    });

    describe('rendering', () => {
      it('renders the gl-paginated-list', () => {
        expect(findGlPaginatedList().exists()).toBe(true);
      });
    });
  });
});
