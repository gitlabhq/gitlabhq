import { defineStore } from 'infection-pkg';

export const useThing = defineStore('thing', {
  state: () => ({ count: 0 }),
});
