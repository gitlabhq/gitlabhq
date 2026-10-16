import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TodosGroup from '~/todos/components/todos_group.vue';
import TodoItem from '~/todos/components/todo_item.vue';
import TodoItemTitle from '~/todos/components/todo_item_title.vue';
import TodoItemTitleHiddenBySaml from '~/todos/components/todo_item_title_hidden_by_saml.vue';
import { MR_REVIEW_REQUEST_TODO, SAML_HIDDEN_TODO } from '../mock_data';

describe('TodosGroup', () => {
  let wrapper;

  const firstTodo = MR_REVIEW_REQUEST_TODO;
  const secondTodo = { ...MR_REVIEW_REQUEST_TODO, id: 'gid://gitlab/Todo/30' };

  const createComponent = ({ todos = [firstTodo, secondTodo], selectedIds = [] } = {}) => {
    wrapper = shallowMountExtended(TodosGroup, {
      propsData: { todos, selectedIds },
    });
  };

  const findTodoItems = () => wrapper.findAllComponents(TodoItem);
  const findHeaderTitle = () => wrapper.findComponent(TodoItemTitle);
  const findCountNumber = () => wrapper.findByTestId('todos-group-count-number');
  const findCountLabel = () => wrapper.findByTestId('todos-group-count-label');
  const findToggle = () => wrapper.findComponentByTestId('todos-group-toggle');
  const findList = () => wrapper.find('ol');

  describe('header', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows the target name of the first to-do', () => {
      expect(findHeaderTitle().props()).toMatchObject({
        todo: firstTodo,
        targetNameOnly: true,
      });
    });

    it('shows the number of to-dos with a label for screen readers', () => {
      expect(findCountNumber().text()).toBe('2');
      expect(findCountNumber().attributes('aria-hidden')).toBe('true');
      expect(findCountLabel().text()).toBe('2 to-dos');
    });
  });

  describe('when the target is hidden by SAML', () => {
    beforeEach(() => {
      createComponent({ todos: [SAML_HIDDEN_TODO] });
    });

    it('shows the hidden title instead of the target name', () => {
      expect(wrapper.findComponent(TodoItemTitleHiddenBySaml).exists()).toBe(true);
      expect(findHeaderTitle().exists()).toBe(false);
    });

    it('labels the collapse toggle without the target name', () => {
      expect(findToggle().attributes('aria-label')).toBe('Show or hide to-dos');
    });
  });

  describe('to-do items', () => {
    beforeEach(() => {
      createComponent({ selectedIds: [secondTodo.id] });
    });

    it('renders a selectable item without the target name for each to-do', () => {
      expect(findTodoItems()).toHaveLength(2);
      expect(findTodoItems().at(0).props()).toMatchObject({
        todo: firstTodo,
        selectable: true,
        hideTargetName: true,
        selected: false,
      });
      expect(findTodoItems().at(1).props('selected')).toBe(true);
    });

    it('re-emits the change event', () => {
      findTodoItems().at(0).vm.$emit('change');

      expect(wrapper.emitted('change')).toHaveLength(1);
    });

    it('re-emits the select-change event', () => {
      findTodoItems().at(1).vm.$emit('select-change', secondTodo.id, false);

      expect(wrapper.emitted('select-change')).toEqual([[secondTodo.id, false]]);
    });
  });

  describe('collapse toggle', () => {
    beforeEach(() => {
      createComponent();
    });

    it('is expanded by default', () => {
      expect(findList().isVisible()).toBe(true);
      expect(findToggle().props('icon')).toBe('chevron-up');
      expect(findToggle().attributes()).toMatchObject({
        'aria-label': 'Show or hide to-dos for Can be automatically merged',
        'aria-expanded': 'true',
        'aria-controls': findList().attributes('id'),
      });
    });

    describe('when clicked', () => {
      beforeEach(async () => {
        findToggle().vm.$emit('click');
        await nextTick();
      });

      it('hides the to-dos', () => {
        expect(findList().isVisible()).toBe(false);
        expect(findToggle().props('icon')).toBe('chevron-down');
        expect(findToggle().attributes()).toMatchObject({
          'aria-label': 'Show or hide to-dos for Can be automatically merged',
          'aria-expanded': 'false',
        });
      });

      it('keeps the header visible', () => {
        expect(findHeaderTitle().exists()).toBe(true);
        expect(findCountNumber().text()).toBe('2');
      });
    });
  });
});
