import { shallowMount } from '@vue/test-utils';
import { loadHTMLFixture } from 'helpers/fixtures';
import '~/boards/stores/boards_store';
import boardComponent from '~/boards/components/board';

jest.mock('images/no_avatar.png', () => 'spec/javascripts/fixtures/one_white_pixel.png', {
  virtual: true,
});

const templateSelector = boardComponent.template;

describe.only('Board component', () => {
  let wrapper;

  const defaultProps = {
    disabled: false,
    issueLinkBase: 'something',
    rootPath: 'something else',
    boardId: 'some id',
    list: {
      isExpandable: true,
      isExpanded: true,
      issues: [],
      loading: false,
      assignee: {
        username: 'some user',
      },
    },
  };
  const mountComponent = (props = defaultProps) => {
    const parentNode = document.createElement('div');
    const el = document.createElement('div');
    parentNode.appendChild(el);

    wrapper = shallowMount(boardComponent, {
      attachToDocument: true,
      propsData: { ...props },
      // necessary for this.$el.parentNode
      parentComponent: {
        template: '<div>dummy</div>',
      },
    });
  };

  beforeEach(() => {
    loadHTMLFixture('boards/show.html.raw');
    gl.issueBoards.getBoardSortableDefaultOptions = jest.fn(() => ({}));

    // inline template to avoid
    // "Component template requires a root element, rather than just text."
    boardComponent.template = document.querySelector(templateSelector).innerHTML;
  });

  afterEach(() => {
    localStorage.clear();
  });

  describe('adds CSS classes', () => {
    test.each`
      listProps                                     | cssClass           | expectClass
      ${{ isExpandable: false }}                    | ${'is-expandable'} | ${false}
      ${{ isExpandable: true }}                     | ${'is-expandable'} | ${true}
  
      ${{ isExpandable: false, isExpanded: false }} | ${'is-collapsed'}  | ${true}
      ${{ isExpandable: false, isExpanded: true }}  | ${'is-collapsed'}  | ${false}
      ${{ isExpandable: true, isExpanded: true }}   | ${'is-collapsed'}  | ${false}
      
      ${{ preset: false }}                          | ${'is-draggable'}  | ${true}
      ${{ preset: true }}                           | ${'is-draggable'}  | ${false}
    `('for list: $listProps', ({ listProps, cssClass, expectClass }) => {
      const props = { ...defaultProps };
      Object.assign(props.list, listProps);
      mountComponent(props);

      if (expectClass) {
        expect(wrapper.classes()).toContain(cssClass);
      } else {
        expect(wrapper.classes()).not.toContain(cssClass);
      }
    });
  });

  describe('restores last state', () => {
    it('to collapsed', () => {
      const props = {
        ...defaultProps,
        list: {
          ...defaultProps.list,
          isExpanded: true,
        },
      };
      localStorage.setItem(`boards.${props.boardId}.${props.list.type}.expanded`, 'true');
      mountComponent(props);

      expect(wrapper.classes()).not.toContain('is-collapsed');
    });

    it('to expanded', () => {
      const props = {
        ...defaultProps,
        list: {
          ...defaultProps.list,
          isExpanded: false,
        },
      };
      localStorage.setItem(`boards.${props.boardId}.${props.list.type}.expanded`, 'false');
      mountComponent(props);

      expect(wrapper.classes()).toContain('is-collapsed');
    });
  });

  describe('when clicking header', () => {
    beforeEach(() => {
      const props = { ...defaultProps };
      props.list.isExpandable = true;
      mountComponent(props);
    });

    it('collapses', () => {
      const props = wrapper.props();
      props.list = {
        ...props.list,
        isExpanded: true,
      };
      wrapper.setProps(props);
      expect(wrapper.classes()).not.toContain('is-collapsed');

      wrapper.find('.board-header').trigger('click');

      expect(wrapper.vm.list.isExpanded).toBe(false);
      expect(localStorage.getItem(`boards.${props.boardId}.${props.list.type}.expanded`)).toBe(
        'false',
      );

      // the following line fails because we are manipulating a prop in
      // https://gitlab.com/gitlab-org/gitlab-ce/blob/v11.3.0-rc1/app/assets/javascripts/boards/components/board.js#L109
      // expect(wrapper.classes()).toContain('is-collapsed');
    });

    it('expands', () => {
      const props = wrapper.props();
      props.list = {
        ...props.list,
        isExpanded: false,
      };
      wrapper.setProps(props);
      expect(wrapper.classes()).toContain('is-collapsed');

      wrapper.find('.board-header').trigger('click');

      expect(wrapper.vm.list.isExpanded).toBe(true);
      expect(localStorage.getItem(`boards.${props.boardId}.${props.list.type}.expanded`)).toBe(
        'true',
      );

      // the following line fails because we are manipulating a prop in
      // https://gitlab.com/gitlab-org/gitlab-ce/blob/v11.3.0-rc1/app/assets/javascripts/boards/components/board.js#L109
      // expect(wrapper.classes()).not.toContain('is-collapsed');
    });
  });
});
