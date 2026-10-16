<script>
import { GlBadge, GlButton } from '@gitlab/ui';
import { uniqueId } from 'lodash-es';
import { n__, s__, sprintf } from '~/locale';
import TodoItem from './todo_item.vue';
import TodoItemTitle from './todo_item_title.vue';
import TodoItemTitleHiddenBySaml from './todo_item_title_hidden_by_saml.vue';

export default {
  name: 'TodosGroup',
  components: {
    GlBadge,
    GlButton,
    TodoItem,
    TodoItemTitle,
    TodoItemTitleHiddenBySaml,
  },
  props: {
    todos: {
      type: Array,
      required: true,
    },
    selectedIds: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  emits: ['change', 'select-change'],
  data() {
    return {
      isCollapsed: false,
      listId: uniqueId('todos-group-list-'),
    };
  },
  computed: {
    firstTodo() {
      return this.todos[0];
    },
    isHiddenBySaml() {
      return !this.firstTodo.targetEntity;
    },
    countLabel() {
      return sprintf(n__('Todos|%{count} to-do', 'Todos|%{count} to-dos', this.todos.length), {
        count: this.todos.length,
      });
    },
    toggleLabel() {
      const name = this.firstTodo.targetEntity?.name;

      return name
        ? sprintf(s__('Todos|Show or hide to-dos for %{name}'), { name })
        : s__('Todos|Show or hide to-dos');
    },
  },
  methods: {
    toggleCollapsed() {
      this.isCollapsed = !this.isCollapsed;
    },
  },
};
</script>

<template>
  <li
    class="gl-rounded-lg gl-bg-strong gl-px-2"
    :class="{ 'gl-pb-2': !isCollapsed }"
    data-testid="todos-group"
  >
    <div class="gl-flex gl-items-center gl-gap-2 gl-py-2 gl-pl-3 gl-pr-1">
      <todo-item-title-hidden-by-saml
        v-if="isHiddenBySaml"
        class="gl-flex gl-min-w-0 gl-items-center gl-gap-2 gl-font-bold"
      />
      <todo-item-title
        v-else
        :todo="firstTodo"
        target-name-only
        class="gl-flex gl-min-w-0 gl-items-center gl-gap-2 gl-whitespace-nowrap gl-font-bold"
      />
      <gl-badge size="sm" data-testid="todos-group-count">
        <span aria-hidden="true" data-testid="todos-group-count-number">{{ todos.length }}</span>
        <span class="gl-sr-only" data-testid="todos-group-count-label">{{ countLabel }}</span>
      </gl-badge>
      <gl-button
        class="gl-ml-auto"
        category="tertiary"
        size="small"
        :icon="isCollapsed ? 'chevron-down' : 'chevron-up'"
        :aria-label="toggleLabel"
        :aria-expanded="String(!isCollapsed)"
        :aria-controls="listId"
        data-testid="todos-group-toggle"
        @click="toggleCollapsed"
      />
    </div>
    <ol
      v-show="!isCollapsed"
      :id="listId"
      class="gl-m-0 gl-list-none gl-overflow-hidden gl-rounded-base gl-bg-default gl-p-0"
    >
      <todo-item
        v-for="todo in todos"
        :key="todo.id"
        :todo="todo"
        class="last:gl-border-b-0"
        selectable
        hide-target-name
        :selected="selectedIds.includes(todo.id)"
        @change="$emit('change')"
        @select-change="(id, checked) => $emit('select-change', id, checked)"
      />
    </ol>
  </li>
</template>
