import { mount } from '@vue/test-utils';
import BoardContentLayout from '~/boards/components/board_content_layout.vue';

const TestComponent = {
  components: { BoardContentLayout },
  template: `
    <div>
      <board-content-layout v-bind="$attrs">
        <template v-slot:board-content-decoration="{ groupId }">
          <p data-testid="child">{{ groupId }}</p>
        </template>
      </board-content-layout>
    </div>
    `,
};

describe('BoardContentLayout', () => {
  let wrapper;
  const groupId = 1;

  const createComponent = props => {
    wrapper = mount(TestComponent, {
      propsData: {
        lists: [],
        canAdminList: true,
        groupId,
        disabled: false,
        issueLinkBase: '',
        rootPath: '',
        boardId: '',
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders children in the slot', () => {
    createComponent();

    expect(wrapper.find('[data-testid="child"]').exists()).toBe(true);
  });

  it('renders groupId from the scoped slot', () => {
    createComponent();

    expect(wrapper.find('[data-testid="child"]').text()).toContain(groupId);
  });

  describe('when isSwimlanesOff', () => {
    it('renders the correct class on the root div', () => {
      createComponent({ isSwimlanesOff: true });

      expect(wrapper.find('[data-testid="boards_list"]').classes()).toEqual([
        'boards-list',
        'gl-w-full',
        'gl-py-5',
        'gl-px-3',
        'gl-white-space-nowrap',
      ]);
    });
  });
});
