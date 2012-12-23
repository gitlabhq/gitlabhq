Login to get private token

```
POST /session
```

Parameters:

+ `email` (required) - The email of user
+ `password` (required) - Valid password


```json
{
  "id": 1,
  "username": "john_smith",
  "email": "john@example.com",
  "name": "John Smith",
  "private_token": "dd34asd13as",
  "created_at": "2012-05-23T08:00:58Z",
  "blocked": true
}
```
