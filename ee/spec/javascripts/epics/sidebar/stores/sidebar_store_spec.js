import SidebarStore from 'ee/epics/sidebar/stores/sidebar_store';

describe('Sidebar Store', () => {
  const dateString = '2017-01-20';

  describe('constructor', () => {
    it('should set startDate', () => {
      const store = new SidebarStore({
        startDate: dateString,
      });
      expect(store.startDate).toEqual(dateString);
    });

    it('should set endDate', () => {
      const store = new SidebarStore({
        endDate: dateString,
      });
      expect(store.endDate).toEqual(dateString);
    });
  });

  describe('startDateTime', () => {
    it('should return null when there is no startDate', () => {
      const store = new SidebarStore({});
      expect(store.startDateTime).toEqual(null);
    });

    it('should return date', () => {
      const store = new SidebarStore({
        startDate: dateString,
      });
      const date = store.startDateTime;

      expect(date.getDate()).toEqual(20);
      expect(date.getMonth()).toEqual(0);
      expect(date.getFullYear()).toEqual(2017);
    });
  });

  describe('startDateTimeFixed', () => {
    it('should return null when there is no startDateFixed', () => {
      const store = new SidebarStore({});
      expect(store.startDateTimeFixed).toEqual(null);
    });

    it('should return date', () => {
      const store = new SidebarStore({
        startDateFixed: dateString,
      });
      const date = store.startDateTimeFixed;

      expect(date.getDate()).toEqual(20);
      expect(date.getMonth()).toEqual(0);
      expect(date.getFullYear()).toEqual(2017);
    });
  });

  describe('endDateTime', () => {
    it('should return null when there is no endDate', () => {
      const store = new SidebarStore({});
      expect(store.endDateTime).toEqual(null);
    });

    it('should return date', () => {
      const store = new SidebarStore({
        endDate: dateString,
      });
      const date = store.endDateTime;

      expect(date.getDate()).toEqual(20);
      expect(date.getMonth()).toEqual(0);
      expect(date.getFullYear()).toEqual(2017);
    });
  });

  describe('dueDateTimeFixed', () => {
    it('should return null when there is no dueDateFixed', () => {
      const store = new SidebarStore({});
      expect(store.dueDateTimeFixed).toEqual(null);
    });

    it('should return date', () => {
      const store = new SidebarStore({
        dueDateFixed: dateString,
      });
      const date = store.dueDateTimeFixed;

      expect(date.getDate()).toEqual(20);
      expect(date.getMonth()).toEqual(0);
      expect(date.getFullYear()).toEqual(2017);
    });
  });

  describe('setSubscribed', () => {
    it('should set store.subscribed value', () => {
      const store = new SidebarStore({ subscribed: true });

      store.setSubscribed(false);
      expect(store.subscribed).toEqual(false);
    });
  });

  describe('setTodoExists', () => {
    it('should set store.subscribed value', () => {
      const store = new SidebarStore({ todoExists: true });

      store.setTodoExists(false);
      expect(store.todoExists).toEqual(false);
    });
  });

  describe('setTodoDeletePath', () => {
    it('should set store.subscribed value', () => {
      const store = new SidebarStore({ todoDeletePath: gl.TEST_HOST });

      store.setTodoDeletePath('/foo/bar');
      expect(store.todoDeletePath).toEqual('/foo/bar');
    });
  });
});
