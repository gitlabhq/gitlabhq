import { uuids } from './uuids';

/**
 * @module recurrence
 */

const instances = {};

/**
 * Create a new unique {@link module:recurrence~RecurInstance|RecurInstance}
 * @returns {module:recurrence.RecurInstance} The newly created {@link module:recurrence~RecurInstance|RecurInstance}
 */
export function create() {
  const id = uuids()[0];
  let handlers = {};
  let count = 0;

  /**
   * @namespace RecurInstance
   * @description A RecurInstance tracks the count of any occurrence as registered by calls to <code>occur</code>.
   * <br /><br />
   * It maintains an internal counter and a registry of handlers that can be arbitrarily assigned by a user.
   * <br /><br />
   * While a RecurInstance isn't specific to any particular use-case, it may be useful for:
   * <br />
   * <ul>
   * <li>Tracking repeated errors across multiple - but not linked - network requests</li>
   * <li>Tracking repeated user interactions (e.g. multiple clicks)</li>
   * </ul>
   * @summary A closure to track repeated occurrences of any arbitrary event.
   * */
  const instance = {
    /**
     * @type {module:uuids~UUIDv4}
     * @description A randomly generated {@link module:uuids~UUIDv4|UUID} for this particular recurrence instance
     * @memberof module:recurrence~RecurInstance
     * @readonly
     * @inner
     */
    get id() {
      return id;
    },
    /**
     * @type {Number}
     * @description The number of times this particular instance of recurrence has been triggered
     * @memberof module:recurrence~RecurInstance
     * @readonly
     * @inner
     */
    get count() {
      return count;
    },
    /**
     * @type {Object}
     * @description The handlers assigned to this recurrence tracker
     * @example
     * myRecurrence.handle( 4, () => console.log( "four" ) );
     * console.log( myRecurrence.handlers ); // {"4": () => console.log( "four" )}
     * @memberof module:recurrence~RecurInstance
     * @readonly
     * @inner
     */
    get handlers() {
      return handlers;
    },
    /**
     * @type {Boolean}
     * @description Delete any internal reference to the instance.
     * <br />
     * Keep in mind that this will only attempt to remove the <strong>internal</strong> reference.
     * <br />
     * If your code maintains a reference to the instance, the regular garbage collector will not free the memory.
     * @memberof module:recurrence~RecurInstance
     * @inner
     */
    free() {
      return delete instances[id];
    },
    /**
     * @description Register a handler to be called when this occurrence is seen <code>onCount</code> number of times.
     * @param {Number} onCount - The number of times the occurrence has been seen to respond to
     * @param {Function} behavior - A callback function to run when the occurrence has been seen <code>onCount</code> times
     * @memberof module:recurrence~RecurInstance
     * @inner
     */
    handle(onCount, behavior) {
      if (onCount && behavior) {
        handlers[onCount] = behavior;
      }
    },
    /**
     * @description Remove the behavior callback handler that would be run when the occurrence is seen <code>onCount</code> times
     * @param {Number} onCount - The count identifier for which to eject the callback handler
     * @memberof module:recurrence~RecurInstance
     * @inner
     */
    eject(onCount) {
      if (onCount) {
        delete handlers[onCount];
      }
    },
    /**
     * @description Register that this occurrence has been seen and trigger any appropriate handlers
     * @memberof module:recurrence~RecurInstance
     * @inner
     */
    occur() {
      count += 1;

      if (typeof handlers[count] === 'function') {
        handlers[count](count);
      }
    },
    /**
     * @description Reset this recurrence instance without destroying it entirely
     * @param {Object} [options]
     * @param {Boolean} [options.currentCount = true] - Whether to reset the count
     * @param {Boolean} [options.handlersList = false] - Whether to reset the list of attached handlers back to an empty state
     * @memberof module:recurrence~RecurInstance
     * @inner
     */
    reset({ currentCount = true, handlersList = false } = {}) {
      if (currentCount) {
        count = 0;
      }

      if (handlersList) {
        handlers = {};
      }
    },
  };

  instances[id] = instance;

  return instance;
}

/**
 * Retrieve a stored {@link module:recurrence~RecurInstance|RecurInstance} by {@link module:uuids~UUIDv4|UUID}
 * @param {module:uuids~UUIDv4} id - The {@link module:uuids~UUIDv4|UUID} of a previously created {@link module:recurrence~RecurInstance|RecurInstance}
 * @returns {(module:recurrence~RecurInstance|undefined)} The {@link module:recurrence~RecurInstance|RecurInstance}, or undefined if the UUID doesn't refer to a known Instance
 */
export function recall(id) {
  return instances[id];
}

/**
 * Release the memory space for a given {@link module:recurrence~RecurInstance|RecurInstance} by {@link module:uuids~UUIDv4|UUID}
 * @param {module:uuids~UUIDv4} id - The {@link module:uuids~UUIDv4|UUID} of a previously created {@link module:recurrence~RecurInstance|RecurInstance}
 * @returns {Boolean} Whether the reference to the stored {@link module:recurrence~RecurInstance|RecurInstance} was released
 */
export function free(id) {
  return recall(id)?.free() || false;
}
