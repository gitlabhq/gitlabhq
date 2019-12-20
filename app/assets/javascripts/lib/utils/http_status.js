/**
 * exports HTTP status codes
 */

const httpStatusCodes = {
  ABORTED: 0,
  OK: 200,
  CREATED: 201,
  ACCEPTED: 202,
  NON_AUTHORITATIVE_INFORMATION: 203,
  NO_CONTENT: 204,
  RESET_CONTENT: 205,
  PARTIAL_CONTENT: 206,
  MULTI_STATUS: 207,
  ALREADY_REPORTED: 208,
  IM_USED: 226,
  MULTIPLE_CHOICES: 300,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  GONE: 410,
  UNPROCESSABLE_ENTITY: 422,
  SERVICE_UNAVAILABLE: 503,
};

export const successCodes = [
  httpStatusCodes.OK,
  httpStatusCodes.CREATED,
  httpStatusCodes.ACCEPTED,
  httpStatusCodes.NON_AUTHORITATIVE_INFORMATION,
  httpStatusCodes.NO_CONTENT,
  httpStatusCodes.RESET_CONTENT,
  httpStatusCodes.PARTIAL_CONTENT,
  httpStatusCodes.MULTI_STATUS,
  httpStatusCodes.ALREADY_REPORTED,
  httpStatusCodes.IM_USED,
];

export default httpStatusCodes;
