<script>
import Store from 'store';
import Service from 'service';
import TodoComponent from 'todoComponent';
export default {
  /**  
   * Although most data belongs in the store, each component it's own state.
   * We want to show a loading spinner while we are fetching the todos, this state belong
   * in the component.
   *
   * We need to access the store methods through all methods of our component.
   * We need to access the state of our store.
   */   
  data() {
    const store = new Store();

    return {
      isLoading: false,
      store: store,
      todos: store.todos,
    };
  },

  components: {
    todo: TodoComponent,
  },

  created() {
    this.service = new Service('todos');

    this.getTodos();
  },

  methods: {
    getTodos() {
      this.isLoading = true;

      this.service.getTodos()
        .then(response => response.json())
        .then((response) => {
          this.store.setTodos(response);
          this.isLoading = false;
        })
        .catch(() => {
          this.isLoading = false;
          // Show an error
        });
    },

    addTodo(todo) {
      this.service.addTodo(todo)
      then(response => response.json())
      .then((response) => {
        this.store.addTodo(response);
      })
      .catch(() => {
        // Show an error
      });
    }
  }
}
</script>
<template>
  <div class="container">
    <div v-if="isLoading">
      <i
        class="fa fa-spin fa-spinner"
        aria-hidden="true" />
    </div>

    <div
      v-if="!isLoading"
      class="js-todo-list">
      <template v-for='todo in todos'>
        <todo :data="todo" />
      </template>

      <button
        @click="addTodo"
        class="js-add-todo">
        Add Todo
      </button>
    </div>
  <div>
</template>
