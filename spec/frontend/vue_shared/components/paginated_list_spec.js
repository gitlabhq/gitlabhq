import { mount } from '@vue/test-utils';
import PaginatedList from '~/vue_shared/components/paginated_list.vue';
import { PREV, NEXT } from '~/vue_shared/components/pagination/constants';

describe('Pagination links component', () => {
  let wrapper;
  let glPaginatedList;

  const template = `
    <div class="slot" slot-scope="{ listItem }">
      <span class="item">Item Name: {{listItem.id}}</span>
    </div>
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
      attachToDocument: true,
    });

    [glPaginatedList] = wrapper.vm.$children;
  });

  afterEach(() => {
    wrapper.destroy();
  });

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
      it('it renders the gl-paginated-list', () => {
        expect(wrapper.contains('ul.list-group')).toBe(true);
        expect(wrapper.findAll('li.list-group-item').length).toBe(2);
      });
    });
  });
});
